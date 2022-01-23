SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramRateCardParameters](
	[ParameterNumber] [int] NOT NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[IsBlankAllowed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[ProgramParameterId] [bigint] NOT NULL,
	[ProgramDetailId] [bigint] NULL,
	[ProgramRateCardId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramRateCardParameters]  WITH CHECK ADD  CONSTRAINT [EProgramRateCard_ProgramRateCardParameters] FOREIGN KEY([ProgramRateCardId])
REFERENCES [dbo].[ProgramRateCards] ([Id])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ProgramRateCardParameters] CHECK CONSTRAINT [EProgramRateCard_ProgramRateCardParameters]
GO
ALTER TABLE [dbo].[ProgramRateCardParameters]  WITH CHECK ADD  CONSTRAINT [EProgramRateCardParameter_ProgramDetail] FOREIGN KEY([ProgramDetailId])
REFERENCES [dbo].[ProgramDetails] ([Id])
GO
ALTER TABLE [dbo].[ProgramRateCardParameters] CHECK CONSTRAINT [EProgramRateCardParameter_ProgramDetail]
GO
ALTER TABLE [dbo].[ProgramRateCardParameters]  WITH CHECK ADD  CONSTRAINT [EProgramRateCardParameter_ProgramParameter] FOREIGN KEY([ProgramParameterId])
REFERENCES [dbo].[ProgramParameterConfigs] ([Id])
GO
ALTER TABLE [dbo].[ProgramRateCardParameters] CHECK CONSTRAINT [EProgramRateCardParameter_ProgramParameter]
GO
