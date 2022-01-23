SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProgramDetails](
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[ActivationDate] [date] NULL,
	[DeactivationDate] [date] NULL,
	[Status] [nvarchar](11) COLLATE Latin1_General_CI_AS NOT NULL,
	[OverrideVendorFee] [bit] NOT NULL,
	[MaxQuoteExpirationDays] [int] NOT NULL,
	[ReceivableCodeId] [bigint] NULL,
	[RowVersion] [timestamp] NOT NULL,
	[IsCreatedFromVendor] [bit] NOT NULL,
	[FeeId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[ProgramDetails]  WITH CHECK ADD  CONSTRAINT [EProgramDetail_Fee] FOREIGN KEY([FeeId])
REFERENCES [dbo].[FeeTypeConfigs] ([Id])
GO
ALTER TABLE [dbo].[ProgramDetails] CHECK CONSTRAINT [EProgramDetail_Fee]
GO
ALTER TABLE [dbo].[ProgramDetails]  WITH CHECK ADD  CONSTRAINT [EProgramDetail_ReceivableCode] FOREIGN KEY([ReceivableCodeId])
REFERENCES [dbo].[ReceivableCodes] ([Id])
GO
ALTER TABLE [dbo].[ProgramDetails] CHECK CONSTRAINT [EProgramDetail_ReceivableCode]
GO
