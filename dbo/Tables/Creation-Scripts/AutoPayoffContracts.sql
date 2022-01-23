SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AutoPayoffContracts](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[IsProcessed] [bit] NOT NULL,
	[IsActive] [bit] NOT NULL,
	[JobStepInstanceId] [bigint] NULL,
	[TaskChunkServiceInstanceId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[AutoPayoffTemplateId] [bigint] NOT NULL,
	[ContractId] [bigint] NOT NULL,
	[RowVersion] [timestamp] NOT NULL,
	[PayoffEffectiveDate] [date] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[AutoPayoffContracts]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffContract_AutoPayoffTemplate] FOREIGN KEY([AutoPayoffTemplateId])
REFERENCES [dbo].[AutoPayoffTemplates] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffContracts] CHECK CONSTRAINT [EAutoPayoffContract_AutoPayoffTemplate]
GO
ALTER TABLE [dbo].[AutoPayoffContracts]  WITH CHECK ADD  CONSTRAINT [EAutoPayoffContract_Contract] FOREIGN KEY([ContractId])
REFERENCES [dbo].[Contracts] ([Id])
GO
ALTER TABLE [dbo].[AutoPayoffContracts] CHECK CONSTRAINT [EAutoPayoffContract_Contract]
GO
